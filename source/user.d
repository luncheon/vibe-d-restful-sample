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
        this.id             = id;
        this.hashedPassword = hash(password);
        this.name           = name;
    }

    @(db.Id)
    string id;
    string hashedPassword;
    string name;

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
    private
    {
        db.SessionFactory _dbSessionFactory;

        db.Session openDbSession()
        {
            return _dbSessionFactory.openSession;
        }
    }

    this(db.SessionFactory dbSessionFactory)
    {
        _dbSessionFactory = dbSessionFactory;
    }

    override
    {
        User[] get()
        {
            return openDbSession.closing.createQuery("FROM User").list!User;
        }

        User get(string id)
        {
            return enforceHTTP(openDbSession.closing.get!User(id), HTTPStatus.notFound);
        }

        void add(string id, string password, string name)
        {
            auto dbSession = openDbSession.closing;
            enforceHTTP(dbSession.get!User(id) is null, HTTPStatus.conflict);
            dbSession.persist(new User(id, password, name));
        }

        void set(string id, string newId, string password, string name)
        {
            auto dbSession = openDbSession.closing;
            auto user = enforceHTTP(dbSession.get!User(id), HTTPStatus.notFound);

            if (newId && newId.length && newId != id)
            {
                enforceHTTP(dbSession.get!User(newId) is null, HTTPStatus.conflict);

                auto newUser = new User(user);
                newUser.id = newId;
                if (password && password.length)
                    newUser.hashedPassword = User.hash(password);
                if (name && name.length)
                    newUser.name = name;

                dbSession.persist(newUser);
                dbSession.remove(user);
            }
            else
            {
                if (name && name.length)
                    user.name = name;
                if (password && password.length)
                    user.hashedPassword = User.hash(password);
                dbSession.update(user);
            }
        }

        void remove(string id)
        {
            auto dbSession = openDbSession.closing;
            dbSession.remove(dbSession.get!User(id));
        }
    }
}
