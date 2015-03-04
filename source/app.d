import user;
import vibe.d;
import hibernated.core;
import std.typetuple;

struct TranslationContext
{
    alias languages = TypeTuple!("en_US", "ja_JP");
    mixin translationModule!"common";
    enum enforceExistingKeys = true;
}

@translationContext!TranslationContext
class WebInterface
{
    void index(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!"index.dt";
    }
}

int main()
{
    auto dataSource = new ConnectionPoolDataSourceImpl(new SQLITEDriver(), "users.db");
    auto sessionFactory = new SessionFactoryImpl(new SchemaInfoImpl!User, new SQLiteDialect, dataSource);
    scope(exit) sessionFactory.close();

    {
        auto connection = dataSource.getConnection();
        scope(exit) connection.close();
        sessionFactory.getDBMetaData().updateDBSchema(connection, false, true);
    }

    auto router = new URLRouter();
    router.get("*", serveStaticFiles("./public/"));
    router.registerWebInterface(new WebInterface);
    router.registerRestInterface(new UserApi(sessionFactory), "users");

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.listenHTTP(router);

    logInfo("Please open http://localhost:8080/ in your browser.");
    return runEventLoop();
}
