import user;
import vibe.d;
import db = hibernated.core;
import std.typetuple;

struct TranslationContext
{
    alias languages = TypeTuple!("en_US", "ja_JP");
    mixin translationModule!"common";
    enum enforceExistingKeys = true;
}
static assert(tr!(TranslationContext, "ja_JP")("language") == "日本語");

@translationContext!TranslationContext
class UserWebInterface
{
    private
    {
        db.SessionFactory _dbSessionFactory;

        User findUser(string id, string password)
        {
            auto dbSession = _dbSessionFactory.openSession;
            scope(exit) dbSession.close;
            auto user = dbSession.get!User(id);
            return (user && user.hashedPassword == User.hash(password)) ? user : null;
        }
    }

    this(db.SessionFactory dbSessionFactory)
    {
        _dbSessionFactory = dbSessionFactory;
    }

    void index(HTTPServerRequest req, HTTPServerResponse res)
    {
        render!"index.dt";
    }

    void login(HTTPServerRequest req, HTTPServerResponse res)
    {
        enforceHTTP("id" in req.form && "password" in req.form, HTTPStatus.badRequest, "Missing id/password field.");

        auto user = findUser(req.form["id"], req.form["password"]);
        enforceHTTP(user, HTTPStatus.unauthorized);

        with (req.session = res.startSession)
        {
            set("user.id", user.id);
            set("user.name", user.name);
        }
        res.redirect("/");
    }

    void logout(HTTPServerRequest req, HTTPServerResponse res)
    {
        terminateSession();
        redirect("/");
    }
}

void checkSession(HTTPServerRequest req, HTTPServerResponse res)
{
    if ([HTTPMethod.POST, HTTPMethod.PUT, HTTPMethod.PATCH, HTTPMethod.DELETE].canFind(req.method) && req.path != "/login")
    {
        enforceHTTP(!req.session.id.empty && !req.session.get!string("user.id").empty, HTTPStatus.forbidden);
    }
}

int run()
{
    auto dbDataSource = new db.ConnectionPoolDataSourceImpl(new db.SQLITEDriver(), "users.db");
    auto dbSessionFactory = new db.SessionFactoryImpl(new db.SchemaInfoImpl!User, new db.SQLiteDialect, dbDataSource);
    scope(exit) dbSessionFactory.close();

    auto router = new URLRouter();
    router.any("*", &checkSession);
    router.get("*", serveStaticFiles("public/"));
    router.registerWebInterface(new UserWebInterface(dbSessionFactory));
    router.registerRestInterface(new UserApi(dbSessionFactory ), "/users");

    auto settings = new HTTPServerSettings;
    settings.port = 8443;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.sessionStore = new MemorySessionStore;
    settings.sslContext = createSSLContext(SSLContextKind.server);
    settings.sslContext.useCertificateChainFile("ssl/server.crt");
    settings.sslContext.usePrivateKeyFile("ssl/server.key");
    settings.listenHTTP(router);

    logInfo("Open https://localhost:8443/ in your browser.");
    return runEventLoop();
}

int initdb()
{
    auto dbDataSource = new db.ConnectionPoolDataSourceImpl(new db.SQLITEDriver(), "users.db");
    auto dbSessionFactory = new db.SessionFactoryImpl(new db.SchemaInfoImpl!User, new db.SQLiteDialect, dbDataSource);
    scope(exit) dbSessionFactory.close();

    auto dbConnection = dbDataSource.getConnection();
    scope(exit) dbConnection.close();
    dbSessionFactory.getDBMetaData.updateDBSchema(dbConnection, true, true);

    auto dbSession = dbSessionFactory.openSession();
    scope(exit) dbSession.close();
    dbSession.persist(new User("user", "user", "Initial User"));

    logInfo("Database 'users.db' is initialized.\nInitial user account (id, password) = ('user', 'user')");
    return 0;
}

int buildLocalStorageVersion()
{
    auto file = openFile("public/localstorage.html", FileMode.createTrunc);
    scope (exit) file.close;

    HTTPServerRequest req = null;
    auto trWeb = (string s) => tr!(TranslationContext, "en_US")(s);
    compileDietFile!("index.dt", req, trWeb)(file);
    return 0;
}

int main(string[] args)
{
    auto option = args[1..$].join(" ");
    switch (option)
    {
    case "":
        return run();
    case "initdb":
        return initdb();
    case "localstorage":
        return buildLocalStorageVersion();
    default:
        logError("Unknown option: " ~ option);
        return 1;
    }

}
