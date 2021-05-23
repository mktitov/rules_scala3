package rules_scala
package common.worker

import java.io.{ByteArrayInputStream, ByteArrayOutputStream, InputStream, PrintStream}
import java.lang.SecurityManager
import java.security.Permission

import scala.annotation.tailrec
import scala.util.control.NonFatal

import com.google.devtools.build.lib.worker.WorkerProtocol

final case class ExitTrapped(code: Int) extends Throwable

trait WorkerMain[S]:
  protected def init(args: Option[Array[String]]): S

  protected def work(ctx: S, args: Array[String]): Unit

  final def main(args: Array[String]): Unit =
    args.toList match
      case "--persistent_worker" :: args =>
        val stdin = System.in
        val stdout = System.out
        val stderr = System.err

        System.setSecurityManager(new SecurityManager:
          val Exit = raw"exitVM\.(-?\d+)".r
          override def checkPermission(permission: Permission): Unit =
            permission.getName match
              case Exit(code) =>
                stderr.println(s"ScalaCompile worker startup failure: permission=$permission, args=${args.mkString("[", ", ", "]")}")
                throw new ExitTrapped(code.toInt)
              case _ =>
        )

        val outStream = new ByteArrayOutputStream
        val out = new PrintStream(outStream)

        System.setIn(new ByteArrayInputStream(Array.emptyByteArray))
        System.setOut(out)
        System.setErr(out)

        @tailrec def process(ctx: S): S =
          val request = WorkerProtocol.WorkRequest.parseDelimitedFrom(stdin)
          val args: Array[String] = Option(request.getArgumentsList()).map(_.toArray(Array.empty[String])).getOrElse(Array.empty)

          val code =
            try
              work(ctx, args)
              0
            catch
              case ExitTrapped(code) => code
              case NonFatal(e) =>
                e.printStackTrace()
                1

          WorkerProtocol.WorkResponse.newBuilder
            .setOutput(outStream.toString)
            .setExitCode(code)
            .build
            .writeDelimitedTo(stdout)

          out.flush()
          outStream.reset()

          process(ctx)
        end process

        try process(init(Some(args.toArray)))
        finally
          System.setIn(stdin)
          System.setOut(stdout)
          System.setErr(stderr)
      case args => work(init(None), args.toArray)
