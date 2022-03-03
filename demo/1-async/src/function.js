module.exports = (_, event) =>
    new Promise( resolve => setTimeout(() => resolve(event), 1000) )
