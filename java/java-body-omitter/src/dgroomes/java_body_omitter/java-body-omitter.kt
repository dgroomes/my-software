package dgroomes.java_body_omitter

import com.github.javaparser.StaticJavaParser
import com.github.javaparser.ast.body.ConstructorDeclaration
import com.github.javaparser.ast.body.InitializerDeclaration
import com.github.javaparser.ast.body.MethodDeclaration
import com.github.javaparser.ast.comments.LineComment
import com.github.javaparser.ast.stmt.BlockStmt
import com.github.javaparser.ast.visitor.ModifierVisitor
import com.github.javaparser.ast.visitor.Visitable
import com.github.javaparser.printer.lexicalpreservation.LexicalPreservingPrinter

/**
 * Please see the README for more information.
 */
fun main() {
    val code = System.`in`.bufferedReader().use { it.readText() }
    val cu = StaticJavaParser.parse(code)

    // Setup LexicalPreservingPrinter to preserve original formatting
    LexicalPreservingPrinter.setup(cu)

    // Remove method bodies
    cu.accept(MethodBodyOmitter(), null)

    // Print the modified code
    println(LexicalPreservingPrinter.print(cu))
}

private class MethodBodyOmitter : ModifierVisitor<Void?>() {
    override fun visit(md: MethodDeclaration, arg: Void?): Visitable {
        // Remove the method body and replace it with a comment
        if (md.body.isPresent) {
            md.body.get().remove()
            val newBody = BlockStmt()
            newBody.addOrphanComment(LineComment("OMITTED"))
            md.setBody(newBody)
        }
        return super.visit(md, arg)
    }

    override fun visit(cd: ConstructorDeclaration, arg: Void?): Visitable {
        // Remove the constructor body and replace it with a comment
        if (cd.body != null) {
            cd.body.remove()
            val newBody = BlockStmt()
            newBody.addOrphanComment(LineComment("OMITTED"))
            cd.setBody(newBody)
        }
        return super.visit(cd, arg)
    }

    override fun visit(id: InitializerDeclaration, arg: Void?): Visitable {
        // Remove the initializer body and replace it with a comment
        if (id.body != null) {
            id.body.remove()
            val newBody = BlockStmt()
            newBody.addOrphanComment(LineComment("OMITTED"))
            id.setBody(newBody)
        }
        return super.visit(id, arg)
    }
}
