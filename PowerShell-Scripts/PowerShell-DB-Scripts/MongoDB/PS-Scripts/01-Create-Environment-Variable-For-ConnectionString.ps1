# Run once in a PS session (user scope)
# Find the Connection String from MongoDB Atlas and paste it below 
[Environment]::SetEnvironmentVariable(
    "MONGO_CONN_STRING",
    "[YOUR_MONGODB_CONNECTION_STRING]",
    "User"
)