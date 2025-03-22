import ballerina/http;
import ballerina/time;

public type User record {|
    readonly int id;
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

public type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

table<User> key(id) usersTable = table [];

@http:ServiceConfig{
    cors: {
        allowOrigins: ["*"]
    }
}
service /socialmedia on new http:Listener(9095) {

    resource function get users() returns User[]|error {
        return usersTable.toArray();
    }

    resource function post users(NewUser newUser) returns User|error {
        int id = usersTable.length();
        User user = {id: id, name: newUser.name, birthDate: newUser.birthDate, mobileNumber: newUser.mobileNumber};
        usersTable.add(user);
        return user;
    }

    resource function delete users/[int id]() returns http:NoContent|error {
        User? _ = usersTable.removeIfHasKey(id);
        return http:NO_CONTENT;
    }

    resource function get users/[int id]() returns User|http:NotFound|error {
        User? user = usersTable.get(id);
        if (user is User) {
            return user;
        }
        return http:NOT_FOUND;
    }
}
