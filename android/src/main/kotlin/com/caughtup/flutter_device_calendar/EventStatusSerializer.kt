package com.caughtup.flutter_device_calendar

import com.caughtup.flutter_device_calendar.models.EventStatus
import com.google.gson.*
import java.lang.reflect.Type

class EventStatusSerializer: JsonSerializer<EventStatus> {
    override fun serialize(src: EventStatus?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        if(src != null) {
            return JsonPrimitive(src.name)
        }
        return JsonObject()
    }

}