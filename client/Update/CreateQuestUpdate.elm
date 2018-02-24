module Update.CreateQuestUpdate
    exposing
        ( createQuestUpdate
        , createQuestInitialModel
        , CreateQuestModel
        )

import Navigation
import Html.Attributes exposing (name)
import Message exposing (Message, Message(..))
import Message.CreateQuestMessage exposing (CreateQuestMessage, CreateQuestMessage(..))
import Request.CreateQuestRequest exposing (createQuestRequest)
import Update.RouteUpdate exposing (parseLocation)
import Ports exposing (requestQuestStepId, requestQuestId, uploadQuestImage)
import Types exposing (SessionModel, Route(..))
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
    , imageUploadModalOpen : Bool
    , imageUploadModalFor : Maybe String
    , imageUploadPath : Maybe String
    , questImageUploadPending : Bool
    , questImageUploadError : Bool
    , submitPending : Bool
    , submitError : Bool
    , token : Maybe String
    }


createQuestInitialModel =
    { id = ""
    , questName = ""
    , questDescription = ""
    , questImageUrl = "/placeholder.png"
    , questSteps = Array.empty
    , imageUploadModalOpen = False
    , imageUploadModalFor = Nothing
    , imageUploadPath = Nothing
    , questImageUploadPending = False
    , questImageUploadError = False
    , submitPending = False
    , submitError = False
    , token = Nothing
    }


onMountCreateQuestView : CreateQuestModel -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
onMountCreateQuestView createQuest commands =
    ( ({ createQuestInitialModel | token = createQuest.token })
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


onCreateQuestMessage : CreateQuestMessage -> ( SessionModel, CreateQuestModel ) -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
onCreateQuestMessage createQuestMessage ( session, createQuest ) commands =
    case createQuestMessage of
        SubmitCreateQuest ->
            ( { createQuest
                | submitPending = True
                , submitError = False
              }
            , (commands
                ++ [ Cmd.map CreateQuest
                        (createQuestRequest
                            session.flags.apiEndpoint
                            (Maybe.withDefault "" session.token)
                            { id = createQuest.id
                            , name = createQuest.questName
                            , description = createQuest.questDescription
                            , imageUrl = createQuest.questImageUrl
                            }
                        )
                   ]
              )
            )

        SubmitCreateQuestResult (Result.Ok quest) ->
            ( createQuest
            , (commands
                ++ [ Navigation.modifyUrl "/#profile" ]
              )
            )

        SubmitCreateQuestResult (Result.Err _) ->
            ( { createQuest
                | submitError = True
              }
            , commands
            )

        OnFileChosen filePath ->
            ( { createQuest
                | imageUploadPath = Just filePath
              }
            , commands
            )

        ShowFileUploadModal id ->
            ( { createQuest
                | imageUploadModalOpen = True
                , imageUploadPath = Nothing
                , imageUploadModalFor = Just id
              }
            , commands
            )

        HideFileUploadModal ->
            ( { createQuest
                | imageUploadModalOpen = False
                , imageUploadPath = Nothing
              }
            , commands
            )

        ConfirmFileUpload id ->
            ( { createQuest
                | questImageUploadPending = True
                , questImageUploadError = False
              }
            , commands ++ [ uploadQuestImage ("fileinput-" ++ id) ]
            )

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


createQuestUpdate : Message -> ( SessionModel, CreateQuestModel ) -> List (Cmd Message) -> ( CreateQuestModel, List (Cmd Message) )
createQuestUpdate message ( session, createQuest ) commands =
    case message of
        UploadQuestImageFinished ( success, questImageUrl ) ->
            if success then
                ( { createQuest
                    | questImageUploadPending = False
                    , questImageUploadError = True
                    , questImageUrl = questImageUrl
                    , imageUploadModalOpen = False
                  }
                , commands
                )
            else
                ( { createQuest
                    | questImageUploadPending = False
                    , questImageUploadError = True
                  }
                , commands
                )

        CreateQuest createQuestMessage ->
            onCreateQuestMessage createQuestMessage ( session, createQuest ) commands

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
                ( route, locationData ) =
                    parseLocation location
            in
                case route of
                    CreateQuestRoute ->
                        onMountCreateQuestView createQuest commands

                    _ ->
                        ( createQuest, commands )

        _ ->
            ( createQuest, commands )
