package dgroomes

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import org.slf4j.Logger
import org.slf4j.LoggerFactory

class SaveProjectDetailsToFileAction : AnAction() {
    private val log: Logger = LoggerFactory.getLogger(SaveProjectDetailsToFileAction::class.java)

    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: run {
            log.error("Project was null.")
            return
        }

        val service = project.getService(ProjectDetailsService::class.java)
        service.saveProjectDetailsToFile()
    }
}
