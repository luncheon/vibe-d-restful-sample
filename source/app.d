import vibe.d;
import std.algorithm;

struct User
{
    int    index;
    string id;
    string name;
}

interface IUserApi
{
    @path("")    User[] get();
    @path(":id") User   get(string _id);
    @path("")    void   add(string id_, string name);
    @path(":id") void   set(string _id, string id_ = "", string name = ""); 
    @path(":id") void   remove(string _id);
}

class UserApi : IUserApi
{
    private User[string] _users;
    private int _lastIndex;

    this(User[] users)
    {
        _lastIndex = users.map!(user => user.index).reduce!max;
        foreach (user; users)
        {
            _users[user.id] = user;
        }
    }

    override
    {
        User[] get()
        {
            return _users.values.sort!"a.index < b.index".array;
        }

        User get(string id)
        {
            return *enforceHTTP(id in _users, HTTPStatus.notFound);
        }

        void add(string id, string name)
        {
            enforceHTTP(id && id.length && name && name.length, HTTPStatus.badRequest);
            enforceHTTP(id !in _users, HTTPStatus.conflict);
            _users[id] = User(++_lastIndex, id, name);
        }

        void set(string id, string newId = null, string name = null)
        {
            if (newId && newId.length && newId != id)
            {
                enforceHTTP(newId !in _users, HTTPStatus.conflict);
                auto user = *enforceHTTP(id in _users, HTTPStatus.notFound);
                _users.remove(id);
                _users[newId] = User(user.index, newId, name && name.length ? name : user.name);
            }
            else if (name && name.length)
            {
                enforceHTTP(id in _users, HTTPStatus.notFound).name = name;
            }
        }

        void remove(string id)
        {
            _users.remove(id);
        }
    }
}

shared static this()
{
    auto router = new URLRouter();
    router.get("/", (req, res) => res.render!("index.dt", req));
    router.get("*", serveStaticFiles("./public/"));
    router.registerRestInterface(new UserApi([User(1, "alice", "Alice"), User(2, "bob", "Bob")]), "users");

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.listenHTTP(router);

    logInfo("Please open http://localhost:8080/ in your browser.");
}
