module.exports = {
    'content-filter': (_, event) => event.data.filter ? null : event,
    'attr-type-filter': (_, event) => event.type === 'my.event.type' ? event : null
}