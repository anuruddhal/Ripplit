function mapPostToPostwithMeta(Post post, string author) returns PostWithMeta => {
    id: post.id,
    description: post.description,
    author: author,
    meta: {
        createdTimeStamp: post.createdTimeStamp,
        category: post.category,
        tags: re `,`.split(post.tags)

    }
};
