package dgroomes.nushell_intellij_plugin

import com.intellij.notification.Notification
import com.intellij.notification.NotificationAction
import com.intellij.notification.NotificationType
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.fileEditor.FileEditor
import com.intellij.openapi.project.DumbAware
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.ProjectManager
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.ui.EditorNotificationPanel
import com.intellij.ui.EditorNotificationProvider
import com.intellij.ui.EditorNotifications
import java.util.function.Function
import javax.swing.JComponent

internal data class NushellSidecarFailure(
    val summary: String,
    val details: String,
) {
    val bannerText: String get() = "Nushell native lexer is unavailable: $summary"
}

internal object NushellSidecarHealth {
    private val log = logger<NushellSidecarHealth>()
    private val lock = Any()

    @Volatile private var failure: NushellSidecarFailure? = null
    @Volatile private var balloonShownForCurrentFailure: Boolean = false

    fun currentFailure(): NushellSidecarFailure? = failure

    fun recordExtractionFailure(error: Throwable) {
        recordFailure(
            summary = "the bundled nu-lex binary could not be prepared",
            details = "The bundled `nu-lex` sidecar could not be extracted from the plugin or written " +
                    "to the IDE system directory. Cause: ${rootCauseMessage(error)}. Rebuild and reinstall " +
                    "the plugin, then click Retry.",
            error = error,
        )
    }

    fun recordInvocationFailure(error: Throwable) {
        recordFailure(
            summary = "the nu-lex sidecar could not be started or stopped responding",
            details = "The `nu-lex` sidecar could not be started or it failed while lexing. " +
                    "Cause: ${rootCauseMessage(error)}. Rebuild `rust/nu-lex`, reinstall the plugin if needed, " +
                    "then click Retry.",
            error = error,
        )
    }

    fun clearFailure() {
        synchronized(lock) {
            failure = null
            balloonShownForCurrentFailure = false
        }
        refreshEditorNotifications()
    }

    private fun recordFailure(summary: String, details: String, error: Throwable) {
        val snapshot = synchronized(lock) {
            if (failure != null) return
            failure = NushellSidecarFailure(summary, details)
            failure!!
        }

        log.warn("${snapshot.bannerText}. ${snapshot.details}", error)
        refreshEditorNotifications()
        showStickyBalloon(snapshot)
    }

    private fun refreshEditorNotifications() {
        ApplicationManager.getApplication().invokeLater {
            EditorNotifications.updateAll()
        }
    }

    private fun showStickyBalloon(failure: NushellSidecarFailure) {
        val shouldShow = synchronized(lock) {
            if (balloonShownForCurrentFailure) {
                false
            } else {
                balloonShownForCurrentFailure = true
                true
            }
        }
        if (!shouldShow) return

        ApplicationManager.getApplication().invokeLater {
            val openProjects = ProjectManager.getInstance().openProjects
            if (openProjects.isEmpty()) {
                createFailureNotification(failure).notify(null)
            } else {
                for (project in openProjects) {
                    createFailureNotification(failure).notify(project)
                }
            }
        }
    }

    private fun createFailureNotification(failure: NushellSidecarFailure): Notification =
        Notification(
            SIDE_CAR_NOTIFICATION_GROUP_ID,
            "Nushell native lexer is unavailable",
            failure.details,
            NotificationType.ERROR,
        ).addAction(NotificationAction.createSimpleExpiring("Retry") {
            NushellLexService.retry()
        })

    private fun rootCauseMessage(error: Throwable): String {
        var current: Throwable? = error
        while (current != null) {
            val message = current.message?.lineSequence()?.firstOrNull()?.trim()
            if (!message.isNullOrBlank()) return message
            current = current.cause
        }
        return error::class.java.simpleName
    }
}

internal class NushellSidecarNotificationProvider : EditorNotificationProvider, DumbAware {
    override fun collectNotificationData(
        project: Project,
        file: VirtualFile,
    ): Function<in FileEditor, out JComponent?>? {
        if (file.fileType !is NushellFileType && file.extension != "nu") return null
        val failure = NushellSidecarHealth.currentFailure() ?: return null

        return Function { fileEditor ->
            EditorNotificationPanel(fileEditor, EditorNotificationPanel.Status.Error).apply {
                text = failure.bannerText
                createActionLabel("Retry") {
                    NushellLexService.retry()
                    EditorNotifications.getInstance(project).updateAllNotifications()
                }
            }
        }
    }
}

private const val SIDE_CAR_NOTIFICATION_GROUP_ID = "Nushell sidecar"
