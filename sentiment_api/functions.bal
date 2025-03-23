import ballerinax/np;

function analyseContext(Post post, np:Prompt prompt = `You are an expert content reviewer for a social media site that categorizes posts under the following categories: "pos", "neg", "neutral"

    Your tasks are:
    1. Suggest a suitable category for the blog from exactly the specified categories. 
       If there is no match, use null.

    2. Rate the blog post on probability value of it being postive, negative or neutral. Sum of values should be 1.

Here is the blog post content:
    Content: ${post.text}`) returns SentimentAIOutput|error = @np:NaturalFunction external;
