module.exports = async (context, event) => {
    const redisClient = context.redisClient

    const value = await redisClient.get(event.id)
    if (!value) {
        await redisClient.set(event.id, JSON.stringify(event))
        return event
    }
    return JSON.parse(value)
}
