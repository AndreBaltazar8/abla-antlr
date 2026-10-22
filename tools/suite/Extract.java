// Extract TARGET TEMPLATES.stg OUT.jsonl: writes ANTLR's runtime testsuite
// descriptors as JSON lines, grammars rendered with the target's templates.
import org.antlr.v4.runtime.misc.Pair;
import org.antlr.v4.test.runtime.RuntimeTestDescriptor;
import org.stringtemplate.v4.*;
import java.io.*;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;

public class Extract {
    static String q(String s) {
        if (s == null) return "null";
        StringBuilder b = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"': b.append("\\\""); break;
                case '\\': b.append("\\\\"); break;
                case '\n': b.append("\\n"); break;
                case '\r': b.append("\\r"); break;
                case '\t': b.append("\\t"); break;
                default: if (c < 0x20) b.append(String.format("\\u%04x", (int) c)); else b.append(c);
            }
        }
        return b.append('"').toString();
    }
    static String render(STGroupFile templates, String grammar) {
        STGroup g = new STGroup('<', '>');
        g.registerRenderer(String.class, new StringRenderer());
        g.importTemplates(templates);
        return new ST(g, grammar).render();
    }
    public static void main(String[] args) throws Exception {
        String target = args[0];
        STGroupFile templates = new STGroupFile(args[1], "UTF-8", '<', '>');
        templates.registerRenderer(String.class, new StringRenderer());
        String[] groups = {"CompositeLexers", "CompositeParsers", "FullContextParsing", "LeftRecursion", "LexerErrors", "LexerExec", "Listeners", "ParserErrors", "ParserExec", "ParseTrees", "Performance", "SemPredEvalLexer", "SemPredEvalParser", "Sets"};
        PrintStream out = new PrintStream(new FileOutputStream(args[2]), true, "UTF-8");
        for (String group : groups) {
            Class<?> clazz = Class.forName("org.antlr.v4.test.runtime.descriptors." + group + "Descriptors");
            for (Class<?> nested : clazz.getClasses()) {
                if (!RuntimeTestDescriptor.class.isAssignableFrom(nested) || Modifier.isAbstract(nested.getModifiers())) continue;
                RuntimeTestDescriptor d = (RuntimeTestDescriptor) nested.getDeclaredConstructor().newInstance();
                boolean ignored = d.ignore(target);
                boolean ignoredForNode = d.ignore("Node");
                d.setTarget(target);
                Pair<String, String> g = d.getGrammar();
                StringBuilder slaves = new StringBuilder("[");
                List<Pair<String, String>> sl = d.getSlaveGrammars();
                if (sl != null) for (Pair<String, String> p : sl) {
                    if (slaves.length() > 1) slaves.append(",");
                    slaves.append("{\"name\":").append(q(p.a)).append(",\"raw\":").append(q(p.b)).append(",\"rendered\":").append(q(render(templates, p.b))).append("}");
                }
                slaves.append("]");
                out.println("{\"group\":" + q(group) + ",\"name\":" + q(d.getTestName()) + ",\"type\":" + q(d.getTestType())
                    + ",\"ignored\":" + ignored + ",\"ignoredForNode\":" + ignoredForNode + ",\"grammarName\":" + q(g.a) + ",\"raw\":" + q(g.b) + ",\"rendered\":" + q(render(templates, g.b))
                    + ",\"slaves\":" + slaves + ",\"input\":" + q(d.getInput()) + ",\"output\":" + q(d.getOutput()) + ",\"errors\":" + q(d.getErrors())
                    + ",\"toolErrors\":" + q(d.getANTLRToolErrors()) + ",\"startRule\":" + q(d.getStartRule())
                    + ",\"showDFA\":" + d.showDFA() + ",\"showDiagnosticErrors\":" + d.showDiagnosticErrors() + "}");
            }
        }
        out.close();
    }
}
