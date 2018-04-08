const axios = require('axios')
const components = require('./components')

const apiEndpoint = process.env.NODE_ENV === 'production' ?
  '/api/' :
  'http://localhost:5000/api/'

const app = window.Elm.Main.embed(
  document.getElementById('app'),
  {
    apiEndpoint,
    env: process.env.NODE_ENV
  }
)

document.addEventListener('animationstart', e => {
  if (e.animationName === 'nodeInserted') {
    const target = e.target
    const componentType = target.getAttribute('data-js-component')

    if (componentType) {
      components.mount(target, componentType, app)
    }
  }
}, false)

document.addEventListener('click', e => {
  const dataLink =
    e.target.getAttribute('data-link') ||
    (e.target.parentNode && e.target.parentNode.getAttribute('data-link'))

  if (dataLink) {
    e.preventDefault()
    app.ports.navigate.send(dataLink)
  }
})

app.ports.uploadQuestImage.subscribe(inputId => {
  const fileInput = document.getElementById(inputId)

  if (!fileInput) {
    return
  }

  const data = new FormData()

  data.append('file', fileInput.files[0])

  axios({
    method: 'POST',
    url: apiEndpoint + 'upload',
    data
  })
    .then(res => {
      app.ports.uploadQuestImageFinished.send([true, res.data.file])
    })
    .catch(() => {
      app.ports.uploadQuestImageFinished.send([false, 'error'])
    })
})
