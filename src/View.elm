module View exposing (..)

import Html exposing (Html, div, text)
import Messages exposing (Msg, Msg(..))
import Models exposing (Model)
import Home.View


view : Model -> Html Msg
view model =
    div []
        [ page model ]


page : Model -> Html Msg
page model =
    Html.map Msg (Home.View.view model)
