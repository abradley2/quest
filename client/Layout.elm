module Layout exposing (layout)

import Css exposing (..)
import Css.Colors
import Html
import Html.Events exposing (onWithOptions)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Message exposing (Message, Message(..))
import Message.LayoutMessage exposing (LayoutMessage, LayoutMessage(..))
import Model exposing (Model)


navs : List (Html LayoutMessage)
navs =
    [ li []
        [ a [ href "#home" ] [ text "Home" ]
        ]
    , li []
        [ a [ href "#about" ] [ text "About" ]
        ]
    ]


navbar : Html LayoutMessage
navbar =
    nav []
        [ div
            [ class "nav-wrapper"
            ]
            [ toggleSidenavButton
            , ul [ class "right hide-on-small-only" ] navs
            ]
        ]


toggleSidenavButton : Html LayoutMessage
toggleSidenavButton =
    a
        [ href "javascript:void(0);"
        , class "left brand-logo show-on-small"
        , onClick ToggleSidenav
        ]
        [ text "Menu"
        ]


sideNavtransform isOpen =
    if isOpen then
        "translateX(0%)"
    else
        "translateX(-105%)"


layout : Model -> Html Message -> Html Message
layout model view =
    div
        []
        [ Html.Styled.map Layout navbar
        , Html.Styled.map Layout
            (ul
                [ id "slide-out"
                , class "sidenav"
                , onClick ToggleSidenav
                , style
                    [ ( "transform", sideNavtransform model.layoutModel.sidenavOpen )
                    , ( "transition", ".25s" )
                    ]
                ]
                navs
            )
        , view
        ]
