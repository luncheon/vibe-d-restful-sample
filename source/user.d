import vibe.d;
import hibernated.core;

// hibernated session closing utility
private struct closing
{
    this(hibernated.session.Session session)
    {
        _session = session;
    }
    ~this()
    {
        _session.close();
    }

    hibernated.session.Session _session;
    alias _session this;
}

// entity definition
class User
{
    this(){}
    this(string id, string name)
    {
        this.id   = id;
        this.name = name;
    }

    @Id
    string id;
    string name;
}

// rest api definition
interface IUserApi
{
    @path("")    User[] get();
    @path(":id") User   get(string _id);
    @path("")    void   add(string id_, string name);
    @path(":id") void   set(string _id, string id_ = null, string name = null); 
    @path(":id") void   remove(string _id);
}

// rest api implementation
class UserApi : IUserApi
{
    private
    {
        SessionFactory _sessionFactory;

        hibernated.session.Session openSession()
        {
            return _sessionFactory.openSession;
        }
    }

    this(SessionFactory sessionFactory)
    {
        _sessionFactory = sessionFactory;
    }

    override
    {
        User[] get()
        {
            return openSession.closing.createQuery("FROM User").list!User;
        }

        User get(string id)
        {
            return enforceHTTP(openSession.closing.get!User(id), HTTPStatus.notFound);
        }

        void add(string id, string name)
        {
            auto session = openSession.closing;
            enforceHTTP(session.get!User(id) is null, HTTPStatus.conflict);
            session.persist(new User(id, name));
        }

        void set(string id, string newId, string name)
        {
            auto session = openSession.closing;
            auto user = enforceHTTP(session.get!User(id), HTTPStatus.notFound);

            if (newId && newId.length && newId != id)
            {
                enforceHTTP(session.get!User(newId) is null, HTTPStatus.conflict);
                session.persist(new User(newId, name && name.length ? name : user.name));
                session.remove(user);
            }
            else if (name && name.length)
            {
                user.name = name;
                session.update(user);
            }
        }

        void remove(string id)
        {
            auto session = openSession.closing;
            session.remove(session.get!User(id));
        }
    }
}
