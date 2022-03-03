module.exports = (context, event) => {
    if (context.params.data)
        event.data = context.params.data
    return event
}
