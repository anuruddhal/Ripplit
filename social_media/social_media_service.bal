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

public type Post record {|
    readonly int id;
    int userId;
    string description;
    string tags;
    string category;
    time:Civil createdTimeStamp;
|};

public type NewPost record {|
    string description;
    string tags;
    string category;
|};

type Probability record {
    decimal neg;
    decimal neutral;
    decimal pos;
};

type Sentiment record {
    Probability probability;
    string label;
};

type PostWithMeta record {
    int id;
    string description;
    string author;
    record {|
        string[] tags;
        string category;
        time:Civil createdTimeStamp;

    |} meta;
};

table<User> key(id) usersTable = table [
    {id: 0, name: "Alice", birthDate: {day: 20, month: 5, year: 1990}, mobileNumber: "0771234567"},
    {id: 1, name: "Bob", birthDate: {day: 15, month: 7, year: 1985}, mobileNumber: "0777654321"}
];

table<Post> key(id) postsTable = table [];

@http:ServiceConfig {
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

    resource function get posts() returns PostWithMeta[]|error {
        PostWithMeta[] allUserPosts = [];
        foreach User user in usersTable {
            Post[] userPosts = from Post post in postsTable
                where post.userId == user.id
                select post;

            foreach Post post in userPosts {
                PostWithMeta postWithMeta= mapPostToPostwithMeta(post, user.name);
                allUserPosts.push(postWithMeta);
            }
        }
        return allUserPosts;
    }

    resource function post users/[int id]/posts(NewPost newPost) returns http:Created|http:NotFound|http:Forbidden|error {
        User? user = usersTable.get(id);
        if (user is User) {
            Sentiment sentiment = check sentimentEp->/api/sentiment.post({text: newPost.description});
            if (sentiment.label == "neg") {
                return http:FORBIDDEN;
            }
            int postId = postsTable.length();
            Post post = {
                id: postId,
                userId: id,
                createdTimeStamp: time:utcToCivil(time:utcNow()),
                description: newPost.description,
                tags: newPost.tags,
                category: newPost.category
            };
            postsTable.add(post);
            return http:CREATED;
        }
        return http:NOT_FOUND;
    }
}
