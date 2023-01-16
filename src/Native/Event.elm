module Native.Event exposing
    ( decodeAttribute
    , on
    , onBlur
    , onBusyChange
    , onDateChange
    , onEventWith
    , onFocus
    , onItemTap
    , onLoaded
    , onReturnPress
    , onSelectedIndexChange
    , onTap
    , onTextChange
    , onUnloaded
    , onValueChange
    )

import Html exposing (Attribute)
import Html.Events as Event
import Json.Decode as D
import Json.Encode as E


onTextChange : (String -> msg) -> Attribute msg
onTextChange msg =
    on "textChange" (D.field "value" D.string |> D.map msg)


onTap : msg -> Attribute msg
onTap msg =
    on "tap" (D.succeed msg)


onReturnPress : msg -> Attribute msg
onReturnPress msg =
    on "returnPress" (D.succeed msg)


onFocus : msg -> Attribute msg
onFocus msg =
    on "focus" (D.succeed msg)


onBlur : msg -> Attribute msg
onBlur msg =
    on "blur" (D.succeed msg)


onLoaded : msg -> Attribute msg
onLoaded msg =
    on "loaded" (D.succeed msg)


onUnloaded : msg -> Attribute msg
onUnloaded msg =
    on "unloaded" (D.succeed msg)


onBusyChange : msg -> Attribute msg
onBusyChange msg =
    on "busyChange" (D.succeed msg)


onDateChange : ({ day : Int, month : Int, year : Int } -> msg) -> Attribute msg
onDateChange msg =
    on "dateChange"
        (D.map3 (\day month year -> msg { day = day, month = month, year = year })
            (D.at [ "object", "day" ] D.int)
            (D.at [ "object", "month" ] D.int)
            (D.at [ "object", "year" ] D.int)
        )


onSelectedIndexChange : (Int -> msg) -> Attribute msg
onSelectedIndexChange msg =
    on "selectedIndexChange" (D.field "value" D.int |> D.map msg)


onValueChange : (Float -> msg) -> Attribute msg
onValueChange msg =
    on "valueChange" (D.field "value" D.float |> D.map msg)


onItemTap : (Int -> msg) -> Attribute msg
onItemTap msg =
    on "itemTap" (D.field "index" D.int |> D.map msg)


on : String -> D.Decoder msg -> Attribute msg
on eventName =
    Event.on eventName


{-| Setter keys require atleast one key.
-}
type alias Setter =
    { keys : ( String, List String )
    , assignmentValue : String
    }


encodeSetter : Setter -> E.Value
encodeSetter { keys, assignmentValue } =
    [ ( "keys", E.list E.string (Tuple.first keys :: Tuple.second keys) )
    , ( "value", E.string assignmentValue )
    ]
        |> E.object


type alias EventOptions =
    { methodCalls : List String
    , setters : List Setter
    }



{- Usage:

    listView
    [ N.items model.encodedItems ]
    [ button
      [ N.itemId <| bindingExpression "$value.id"
      , Event.on "tap" (Event.decodeAttribute "itemId" D.string |> D.map ItemTap)
      ]
      []
   ]

-}


decodeAttribute : String -> D.Decoder a -> D.Decoder a
decodeAttribute attributeName decoder =
    D.at [ "object", attributeName ] decoder


{-| Method values are kept under {custom: {[methodName]: value}}

For example:

    Event.onEventWithMethodCalls "touch"
        { methodCalls = [ "getX", "getY" ]
        , setters = []
        , getters = []
        }
        (D.map2 Tuple.pair
            (D.at [ "custom", "getX" ] D.float)
            (D.at [ "custom", "getY" ] D.float)
            |> D.map Msg
        )

-}
onEventWith : String -> EventOptions -> D.Decoder msg -> Attribute msg
onEventWith eventName { methodCalls, setters } =
    let
        encodedValue : String
        encodedValue =
            [ ( "event", E.string eventName )
            , ( "methods", E.list E.string methodCalls )
            , ( "setters", E.list encodeSetter setters )
            ]
                |> E.object
                |> E.encode 0
    in
    Event.on encodedValue
