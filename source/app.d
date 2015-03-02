import vibe.d;

struct User
{
    int id;
    string name;
}

interface IUserApi
{
    @path("")     User[] get();
    @path(":id")  User   get(int _id);
    @path("")     void   add(int id_, string name);
    @path(":id")  void   put(int _id, string name);
    @path(":id")  void   remove(int _id);
}

class UserApi : IUserApi
{
    private User[int] _users;

    this(User[] users)
    {
        foreach (user; users)
        {
            _users[user.id] = user;
        }
    }

    override
    {
        User[] get()
        {
            return _users.values;
        }

        User get(int id)
        {
            return *enforceHTTP(id in _users, HTTPStatus.notFound);
        }

        void add(int id, string name)
        {
            enforceHTTP(id !in _users, HTTPStatus.conflict);
            _users[id] = User(id, name);
        }

        void remove(int id)
        {
            _users.remove(id);
        }

        void put(int id, string name)
        {
            enforceHTTP(id in _users, HTTPStatus.notFound).name = name;
        }
    }
}

shared static this()
{
    auto router = new URLRouter();
    router.get("/", (req, res) => res.render!("index.dt", req));
    router.registerRestInterface(new UserApi([User(1, "Alice"), User(2, "Bob")]), "users");

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.listenHTTP(router);

    logInfo("Please open http://localhost:8080/ in your browser.");
}
