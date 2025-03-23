import ballerina/http;
import ballerina/sql;
import ballerina/time;
import ballerina/log;

public type User record {|
    readonly int id;
    string name;
    @sql:Column {
        name: "birth_date"
    }
    time:Date birthDate;
    @sql:Column {
        name: "mobile_number"
    }
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
    @sql:Column {
        name: "created_time_stamp"
    }
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

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /socialmedia on new http:Listener(9095) {

    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDb->query(`SELECT * FROM users`);
        User[] users = check from User user in userStream
            select user;
        return users;
    }

    resource function post users(NewUser newUser) returns User|error {
        sql:ExecutionResult|sql:Error result = check socialMediaDb->execute(`INSERT INTO users (name, birth_date, mobile_number) 
        VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber})`);
        if (result is sql:Error) {
            return result;
        }
        return {id: <int>result.lastInsertId, name: newUser.name, birthDate: newUser.birthDate, mobileNumber: newUser.mobileNumber};
    }

    resource function delete users/[int id]() returns http:NoContent|error {
        sql:ExecutionResult|sql:Error result = check socialMediaDb->execute(`DELETE FROM users WHERE id = ${id}`);
        if (result is sql:Error) {
            return result;
        }
        return http:NO_CONTENT;
    }

    resource function get users/[int id]() returns User|http:NotFound|error {
        User|error user = socialMediaDb->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if (user is sql:NoRowsError) {
            return http:NOT_FOUND;
        }

        if (user is User) {
            return user;
        }
        return http:NOT_FOUND;
    }

    resource function get posts() returns PostWithMeta[]|error {
        stream<User, sql:Error?> userStream = socialMediaDb->query(`SELECT * FROM users`);
        PostWithMeta[] posts = [];
        User[] users = check from User user in userStream
            select user;

        foreach User user in users {
            stream<Post, sql:Error?> postStream = socialMediaDb->query(`SELECT id, description, category, created_time_stamp, tags FROM posts WHERE user_id = ${user.id}`);
            Post[] userPosts = check from Post post in postStream
                select post;
            foreach Post post in userPosts {
                PostWithMeta postsWithMeta = mapPostToPostwithMeta(post, user.name);
                posts.push(postsWithMeta);
            }
        }
        return posts;
    }

    resource function post users/[int id]/posts(NewPost newPost) returns http:Created|http:NotFound|http:Forbidden|error {
        User|error user = socialMediaDb->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            return http:NOT_FOUND;
        }
        if user is error {
            return user;
        }

        Sentiment sentiment = check sentimentEp->/api/sentiment.post({"text": newPost.description});
        log:printInfo("Sentiment: "+ sentiment.toJsonString());
        if sentiment.label == "neg" {
            return http:FORBIDDEN;
        }

        _ = check socialMediaDb->execute(`
            INSERT INTO posts(description, category, created_time_stamp, tags, user_id)
            VALUES (${newPost.description}, ${newPost.category}, CURRENT_TIMESTAMP(), ${newPost.tags}, ${id});`);
        return http:CREATED;
    }
}
