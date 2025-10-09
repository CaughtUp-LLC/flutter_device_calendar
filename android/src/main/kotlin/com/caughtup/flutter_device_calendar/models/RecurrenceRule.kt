package com.caughtup.flutter_device_calendar.models

import com.caughtup.flutter_device_calendar.common.DayOfWeek
import com.caughtup.flutter_device_calendar.common.RecurrenceFrequency


class RecurrenceRule(val recurrenceFrequency : RecurrenceFrequency) {
    var totalOccurrences: Int? = null
    var interval: Int? = null
    var endDate: Long? = null
    var daysOfWeek: MutableList<DayOfWeek>? = null
    var dayOfMonth: Int? = null
    var monthOfYear: Int? = null
    var weekOfMonth: Int? = null
}
