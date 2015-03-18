import vibe.d;
import db = hibernated.core;
import std.digest.sha;

// hibernated session closing utility
private struct closing
{
    this(db.Session dbSession)
    {
        _dbSession = dbSession;
    }
    ~this()
    {
        _dbSession.close();
    }

    db.Session _dbSession;
    alias _dbSession this;
}

// entity definition
class User
{
    this(){}
    this(in User user)
    {
        this.id             = user.id;
        this.hashedPassword = user.hashedPassword;
        this.name           = user.name;
    }
    this(string id, string password, string name)
    {
        this.id       = id;
        this.password = password;
        this.name     = name;
    }

    @(db.Id)
    string id;
    string hashedPassword;
    string name;

    @property void password(string password)
    {
        hashedPassword = hash(password);
    }

    static pure string hash(string source)
    {
        return (cast(ubyte[])sha224Of(source)).toHexString;
    }
}

// rest api definition
interface IUserApi
{
    @path("")    User[] get();
    @path(":id") User   get(string _id);
    @path("")    void   add(string id_, string password, string name);
    @path(":id") void   set(string _id, string id_ = null, string password = null, string name = null); 
    @path(":id") void   remove(string _id);
}

// rest api implementation
class UserApi : IUserApi
{
    private db.SessionFactory _db;

    this(db.SessionFactory dbSessionFactory)
    {
        _db = dbSessionFactory;
    }

    override
    {
        User[] get()
        {
            return _db.openSession.closing.createQuery("FROM User").list!User;
        }

        User get(string id)
        {
            return enforceHTTP(_db.openSession.closing.get!User(id), HTTPStatus.notFound);
        }

        void add(string id, string password, string name)
        {
            enforceHTTP(!id.empty && !name.empty, HTTPStatus.badRequest, "id and name must not be empty.");
            auto dbSession = _db.openSession.closing;
            enforceHTTP(dbSession.get!User(id) is null, HTTPStatus.conflict, "id `" ~ id ~ "` already exists.");
            dbSession.persist(new User(id, password, name));
        }

        void set(string id, string newId, string password, string name)
        {
            auto dbSession = _db.openSession.closing;
            auto user = enforceHTTP(dbSession.get!User(id), HTTPStatus.notFound);

            if (!newId.empty && newId != id)
            {
                enforceHTTP(dbSession.get!User(newId) is null, HTTPStatus.conflict, "id `" ~ newId ~ "` already exists.");

                auto newUser = new User(user);
                newUser.id = newId;
                if (!password.empty)
                    newUser.password = password;
                if (!name.empty)
                    newUser.name = name;

                dbSession.persist(newUser);
                dbSession.remove(user);
            }
            else
            {
                if (!name.empty)
                    user.name = name;
                if (!password.empty)
                    user.password = password;
                dbSession.update(user);
            }
        }

        void remove(string id)
        {
            auto dbSession = _db.openSession.closing;
            auto user = dbSession.get!User(id);
            user && dbSession.remove(user);
        }
    }
}
