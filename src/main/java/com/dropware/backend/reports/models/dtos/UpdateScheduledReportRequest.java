package com.dropware.backend.reports.models.dtos;

import com.dropware.backend.reports.models.enums.ReportFormat;
import com.dropware.backend.reports.models.enums.ReportFrequency;
import com.dropware.backend.reports.models.enums.ReportType;
import java.time.DayOfWeek;
import java.time.LocalTime;
import lombok.Data;

@Data
// Request payload for updating an existing scheduled report configuration.
public class UpdateScheduledReportRequest {
    private String name;
    private ReportType reportType;
    private ReportFrequency frequency;
    private String recipientEmails;
    private String filterConfig;
    private ReportFormat format;
    private LocalTime scheduleTime;
    private DayOfWeek scheduleDayOfWeek;
    private Integer scheduleDay;
    private Boolean enabled;
}
