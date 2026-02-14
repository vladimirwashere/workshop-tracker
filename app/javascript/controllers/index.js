import { application } from "controllers/application"

import GanttController from "controllers/gantt_controller"
application.register("gantt", GanttController)

import PeriodFilterController from "controllers/period_filter_controller"
application.register("period-filter", PeriodFilterController)

import BackController from "controllers/back_controller"
application.register("back", BackController)

import AutoSubmitController from "controllers/auto_submit_controller"
application.register("auto-submit", AutoSubmitController)

import ProjectTreeController from "controllers/project_tree_controller"
application.register("project-tree", ProjectTreeController)

import DailyLogFormController from "controllers/daily_log_form_controller"
application.register("daily-log-form", DailyLogFormController)

import AttachmentUploadController from "controllers/attachment_upload_controller"
application.register("attachment-upload", AttachmentUploadController)

import LightboxController from "controllers/lightbox_controller"
application.register("lightbox", LightboxController)

import CurrencyToggleController from "controllers/currency_toggle_controller"
application.register("currency-toggle", CurrencyToggleController)

import ReportFiltersController from "controllers/report_filters_controller"
application.register("report-filters", ReportFiltersController)

import ModalController from "controllers/modal_controller"
application.register("modal", ModalController)

import VatToggleController from "controllers/vat_toggle_controller"
application.register("vat-toggle", VatToggleController)

import DateRangeController from "controllers/date_range_controller"
application.register("date-range", DateRangeController)

import WorkerTimelineController from "controllers/worker_timeline_controller"
application.register("worker-timeline", WorkerTimelineController)

import AccountFormController from "controllers/account_form_controller"
application.register("account-form", AccountFormController)

import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)

import ClipboardController from "controllers/clipboard_controller"
application.register("clipboard", ClipboardController)
