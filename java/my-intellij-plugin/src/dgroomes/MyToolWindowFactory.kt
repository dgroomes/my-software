package dgroomes

import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.ui.content.ContentFactory

class MyToolWindowFactory : ToolWindowFactory {

    private val contentFactory: ContentFactory = ContentFactory.getInstance()

    override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
        val window = MyWindow(project)
        val content = contentFactory.createContent(window.rootElement, "", false)
        toolWindow.contentManager.addContent(content)
    }
}
