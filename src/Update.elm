module Update exposing (..)

import Messages exposing (Msg(..))
import Models exposing (Model)
import Home.Update
import Ui.Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HomeMsg subMsg ->
            let
                ( home, cmd ) =
                    Home.Update.update subMsg model.home
            in
                ( { model | home = home }, Cmd.map HomeMsg cmd )

        UiMsg subMsg ->
            let
                ( ui, cmd ) =
                    Ui.Update.update subMsg model.ui
            in
                ( { model | ui = ui }, Cmd.map UiMsg cmd )
