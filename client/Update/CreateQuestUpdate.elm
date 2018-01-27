module Update.CreateQuestUpdate
    exposing
        ( createQuestUpdate
        , createQuestInitialModel
        , CreateQuestModel
        )

import Html.Attributes exposing (name)
import Message exposing (Message, Message(..))
import Message.CreateQuestMessage exposing (CreateQuestMessage, CreateQuestMessage(..))
import Update.RouteUpdate exposing (parseLocation, Route(..))
import Ports exposing (requestQuestStepId, requestQuestId)


type alias QuestStep =
    { id : String
    , name : String
    , description : String
    , imageUrl : String
    }


type alias CreateQuestModel =
    { id : String
    , questName : String
    , questDescription : String
    , questImageUrl : String
    , questSteps : List QuestStep
    }


createQuestInitialModel =
    { id = ""
    , questName = ""
    , questDescription = ""
    , questImageUrl = "/placeholder.png"
    , questSteps = []
    }


onMountCreateQuestView : CreateQuestModel -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
onMountCreateQuestView createQuest commands =
    ( { createQuest
        | questSteps =
            [ { id = Debug.log "placeholder" "placeholder"
              , name = "Quest Name"
              , description = "A short description of the quest"
              , imageUrl = "/placeholder.png"
              }
            ]
      }
    , commands ++ [ requestQuestId "gimme!" ]
    )


onCreateQuestMessage : CreateQuestMessage -> CreateQuestModel -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
onCreateQuestMessage createQuestMessage createQuest commands =
    case createQuestMessage of
        AddQuestStep ->
            ( { createQuest
                | questSteps =
                    createQuest.questSteps
                        ++ [ { id = "newquest"
                             , name = "Quest Name"
                             , description = "A short description of the quest"
                             , imageUrl = "/placeholder.png"
                             }
                           ]
              }
            , commands ++ [ requestQuestStepId "newquest" ]
            )

        NoOp ->
            ( createQuest, commands )

        _ ->
            ( createQuest, commands )


createQuestUpdate : Message -> CreateQuestModel -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
createQuestUpdate message createQuest commands =
    case message of
        CreateQuest createQuestMessage ->
            onCreateQuestMessage createQuestMessage createQuest commands

        LoadQuestId cuid ->
            ( { createQuest | id = cuid }, commands )

        OnLocationChange location ->
            let
                route =
                    parseLocation location
            in
                case route of
                    CreateQuestRoute ->
                        onMountCreateQuestView createQuest commands

                    _ ->
                        ( createQuest, commands )

        _ ->
            ( createQuest, commands )
