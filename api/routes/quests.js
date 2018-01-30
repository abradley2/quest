const uuid = require('uuid')
const router = require('express').Router
const jwt = require('jsonwebtoken')
const co = require('co')
const request = require('axios')
const redis = require('../redis')
const {
  getQuestsListKey,
  getRecentQuestsKey,
  getAcccessTokenKey
} = require('./util/redis-keys')

const questsRouter = router()

const graphApi = 'https://graph.facebook.com/v2.11/'

const formatQuest = quest => Object.assign({}, quest, {
  upvotes: quest.upvotes.length
})

questsRouter.get('/:userId', (req, res) => co(function * () {
  const userId = req.params.userId

  const userQuests = yield redis.lrange(getQuestsListKey(userId), 0, 100)

  return res.json(userQuests.map(q => JSON.parse(q)).map(formatQuest))
}).catch(err => {
  const log = req.app.locals.log

  log.error(err)
  res.status(400).json({success: false})
}))

questsRouter.get('/', (req, res) => co(function * () {
  const recentQuests = yield redis.lrange(
    getRecentQuestsKey(),
    req.params.offset || 0,
    req.params.count || 10
  )

  const pipeline = recentQuests.reduce((pipe, questKey) => {
    const userId = questKey.split(':')[0]

    return pipe.lindex(getQuestsListKey(userId), 0)
  }, redis.multi())

  const results = yield pipeline.exec()

  const quests = results
    .filter(([err, questJSON]) => {
      return !err && questJSON
    })
    .map(([, questJSON]) => JSON.parse(questJSON))
    .filter((quest, idx) => {
      const recentGuid = recentQuests[idx].split(':')[1]

      return recentGuid === quest.guid
    })

  res.json(quests.map(formatQuest))
}).catch(err => {
  const log = req.app.locals.log

  log.error(err, 'error getting recent quests')

  res.status(400).json({success: false})
}))

questsRouter.post('/', (req, res) => co(function * () {
  const {userId, sessionId} = yield jwt.verify(res.locals.token, global.config.appSecret)

  const accessTokenResponse = yield redis.get(getAcccessTokenKey(sessionId))

  const nameResponse = yield request.get(graphApi + '/me?fields=first_name&access_token=' + accessTokenResponse)

  const guid = uuid.v4()
  const quest = {
    guid,
    userId,
    username: nameResponse.data.first_name,
    id: req.body.id,
    name: req.body.name,
    description: req.body.description,
    imageUrl: req.body.imageUrl,
    upvotes: []
  }

  yield redis.multi()
    .lpush(getQuestsListKey(userId), JSON.stringify(quest))
    .lpush(getRecentQuestsKey(), `${userId}:${guid}`)
    .exec()

  res.json(formatQuest(quest))
}).catch(err => {
  const log = req.app.local.log

  log.error(err, 'error creating quest')

  res.status(400).json({success: false})
}))

module.exports = questsRouter
