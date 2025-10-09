package com.caughtup.flutter_device_calendar

import com.caughtup.flutter_device_calendar.models.Availability
import com.google.gson.*
import java.lang.reflect.Type

class AvailabilitySerializer: JsonSerializer<Availability> {
    override fun serialize(src: Availability?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        if(src != null) {
            return JsonPrimitive(src.name)
        }
        return JsonObject()
    }
}