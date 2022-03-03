module.exports = (context, event)  => {
    console.log(`waiting ${context.params.seconds} seconds`)
    return new Promise( resolve => setTimeout(() => resolve(event), context.params.seconds * 1000) )
}
