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
import Array


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
    , questSteps : Array.Array QuestStep
    }


createQuestInitialModel =
    { id = ""
    , questName = ""
    , questDescription = ""
    , questImageUrl = "/placeholder.png"
    , questSteps = Array.empty
    }


onMountCreateQuestView : CreateQuestModel -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
onMountCreateQuestView createQuest commands =
    ( { createQuest
        | questSteps =
            Array.fromList
                [ { id = "placeholder"
                  , name = "Quest Name"
                  , description = "A short description of the quest"
                  , imageUrl = "/placeholder.png"
                  }
                ]
      }
    , commands ++ [ requestQuestId "gimme!" ]
    )


getQuestStepById id questSteps =
    questSteps
        |> Array.indexedMap (\idx questStep -> ( idx, questStep ))
        |> Array.foldr
            (\( idx, questStep ) found ->
                if questStep.id == id then
                    idx
                else
                    found
            )
            -1
        |> (\idx -> ( idx, Array.get idx questSteps ))


questStepEditor : String -> (QuestStep -> QuestStep) -> CreateQuestModel -> CreateQuestModel
questStepEditor stepId setterFunc createQuest =
    let
        ( idx, maybeStep ) =
            getQuestStepById stepId createQuest.questSteps
    in
        case maybeStep of
            Just targetQuestStep ->
                { createQuest
                    | questSteps =
                        Array.set idx (setterFunc targetQuestStep) createQuest.questSteps
                }

            Nothing ->
                createQuest


onCreateQuestMessage : CreateQuestMessage -> CreateQuestModel -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
onCreateQuestMessage createQuestMessage createQuest commands =
    case createQuestMessage of
        EditQuestName questName ->
            ( { createQuest
                | questName = questName
              }
            , commands
            )

        EditQuestDescription questDescription ->
            ( { createQuest
                | questDescription = questDescription
              }
            , commands
            )

        EditQuestStepName questStepId name ->
            ( questStepEditor
                questStepId
                (\questStep -> { questStep | name = name })
                createQuest
            , commands
            )

        EditQuestStepDescription questStepId description ->
            ( questStepEditor
                questStepId
                (\questStep -> { questStep | description = description })
                createQuest
            , commands
            )

        AddQuestStep ->
            ( { createQuest
                | questSteps =
                    Array.append createQuest.questSteps
                        (Array.fromList
                            [ { id = "newquest"
                              , name = ""
                              , description = ""
                              , imageUrl = "/placeholder.png"
                              }
                            ]
                        )
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

        LoadQuestStepId ( prevId, cuid ) ->
            ( questStepEditor
                prevId
                (\questStep -> { questStep | id = cuid })
                createQuest
            , commands
            )

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
