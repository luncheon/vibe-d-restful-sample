import user;
import vibe.d;
import hibernated.core;

int main()
{
    DataSource dataSource = new ConnectionPoolDataSourceImpl(new SQLITEDriver(), "users.db");
    SessionFactory sessionFactory = new SessionFactoryImpl(new SchemaInfoImpl!User, new SQLiteDialect, dataSource);
    scope(exit) sessionFactory.close();

    {
        Connection connection = dataSource.getConnection();
        scope(exit) connection.close();
        sessionFactory.getDBMetaData().updateDBSchema(connection, false, true);
    }

    auto router = new URLRouter();
    router.get("/", (req, res) => res.render!("index.dt", req));
    router.get("*", serveStaticFiles("./public/"));
    router.registerRestInterface(new UserApi(sessionFactory), "users");

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.listenHTTP(router);

    logInfo("Please open http://localhost:8080/ in your browser.");
    return runEventLoop();
}
