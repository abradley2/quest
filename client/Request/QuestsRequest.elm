module Request.QuestsRequest
    exposing
        ( decideSideQuest
        , getQuests
        , getQuestsByUser
        , getSideQuests
        , suggestSideQuest
        , getQuestDetails
        )

import Http
import Msg.SideQuestsMsg exposing (SideQuestsMsg, SideQuestsMsg(..))
import Msg.QuestsMsg exposing (QuestsMsg(..), QuestsMsg)
import Msg.MyAdventurerMsg exposing (MyAdventurerMsg(..), MyAdventurerMsg)
import Msg.QuestDetailsMsg exposing (QuestDetailsMsg(..), QuestDetailsMsg)
import Json.Decode exposing (..)
import Json.Encode as Encode
import Types exposing (RecentPostedQuest, SideQuest, GetSideQuestsResponse, QuestDetailsResponse)


decodeQuestsList =
    Json.Decode.list decodeQuest


decodeSideQuest =
    Json.Decode.map5 SideQuest
        (field "name" string)
        (field "description" string)
        (field "guid" string)
        (field "suggestedBy" string)
        (field "id" string)


decodeSideQuestsList =
    Json.Decode.list decodeSideQuest


decodeQuest =
    Json.Decode.map8 RecentPostedQuest
        (field "name" string)
        (field "description" string)
        (field "imageUrl" string)
        (field "id" string)
        (field "guid" string)
        (field "username" string)
        (field "userId" string)
        (field "upvotes" int)


decodeQuestDetails =
    Json.Decode.map3 QuestDetailsResponse
        (field "quest" decodeQuest)
        (field "sideQuests" (Json.Decode.list decodeSideQuest))
        (field "suggestedSideQuests" (Json.Decode.list decodeSideQuest))


encodeSideQuest sideQuest =
    Encode.object
        [ ( "name", Encode.string sideQuest.name )
        , ( "description", Encode.string sideQuest.description )
        ]


decodeGetSideQuestsResponse =
    Json.Decode.map2 GetSideQuestsResponse
        (field "quest" decodeQuest)
        (field "sideQuests" decodeSideQuestsList)


getQuests : String -> String -> Cmd QuestsMsg
getQuests apiEndpoint userToken =
    let
        request =
            Http.request
                { method = "GET"
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ userToken)
                    ]
                , url = apiEndpoint ++ "quests"
                , body = Http.emptyBody
                , expect = Http.expectJson decodeQuestsList
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send GetQuestsResult request


getSideQuests : String -> String -> String -> String -> Cmd SideQuestsMsg
getSideQuests apiEndpoint userToken userId questId =
    let
        request =
            Http.request
                { method = "GET"
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ userToken)
                    ]
                , url = (apiEndpoint ++ "sidequests/" ++ userId ++ "?questId=" ++ questId)
                , body = Http.emptyBody
                , expect = Http.expectJson decodeGetSideQuestsResponse
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send GetSideQuestsResult request


getQuestsByUser : String -> String -> String -> Cmd MyAdventurerMsg
getQuestsByUser apiEndpoint userToken userId =
    let
        request =
            Http.request
                { method = "GET"
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ userToken)
                    ]
                , url = (apiEndpoint ++ "quests/" ++ userId)
                , body = Http.emptyBody
                , expect = Http.expectJson decodeQuestsList
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send GetQuestsByUserResult request


getQuestDetails : String -> String -> String -> Cmd QuestDetailsMsg
getQuestDetails apiEndpoint userId questId =
    let
        request =
            Http.request
                { method = "GET"
                , headers =
                    []
                , url = (apiEndpoint ++ "quests/details/" ++ userId ++ "/" ++ questId)
                , body = Http.emptyBody
                , expect = Http.expectJson decodeQuestDetails
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send GetQuestDetailsResult request


type alias DecideSideQuestParams =
    { apiEndpoint : String
    , userToken : String
    , questId : String
    , sideQuestId : String
    , isAccepted : Bool
    }


decideSideQuest : DecideSideQuestParams -> Cmd QuestDetailsMsg
decideSideQuest params =
    let
        request =
            Http.request
                { method = "PUT"
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ params.userToken)
                    ]
                , url = (params.apiEndpoint ++ "quests/" ++ params.questId ++ "/decidesidequest")
                , body =
                    Http.jsonBody
                        (Encode.object
                            [ ( "sideQuestId", Encode.string params.sideQuestId )
                            , ( "isAccepted", Encode.bool params.isAccepted )
                            ]
                        )
                , expect = Http.expectJson decodeQuestDetails
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send DecideSideQuestResult request


suggestSideQuest : String -> String -> RecentPostedQuest -> SideQuest -> Cmd SideQuestsMsg
suggestSideQuest apiEndpoint userToken quest sideQuest =
    let
        request =
            Http.request
                { method = "POST"
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ userToken)
                    ]
                , url = (apiEndpoint ++ "sidequests/" ++ quest.userId ++ "/" ++ quest.id)
                , body = Http.jsonBody (encodeSideQuest sideQuest)
                , expect = Http.expectJson (Json.Decode.field "success" bool)
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send SuggestSideQuestResult request
