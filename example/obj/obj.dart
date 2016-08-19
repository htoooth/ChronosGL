import 'package:chronosgl/chronosgl.dart';
import 'package:chronosgl/chronosutil.dart';
import 'dart:html' as HTML;

import 'package:vector_math/vector_math.dart' as VM;

void main() {
  StatsFps fps =
      new StatsFps(HTML.document.getElementById("stats"), "blue", "gray");
  ChronosGL chronosGL = new ChronosGL('#webgl-canvas');

  OrbitCamera orbit = new OrbitCamera(25.0);
  RenderingPhase phase = chronosGL.createPhase(orbit);
  ShaderProgram prg = phase.createProgram(createDemoShader());

  double _lastTimeMs = 0.0;
  void animate(timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs;
    orbit.azimuth += 0.001;
    orbit.animate(elapsed);
    fps.UpdateFrameCount(timeMs);
    chronosGL.draw();
    HTML.window.animationFrame.then(animate);
  }

  loadObj("../ct_logo.obj").then((MeshData md) {
    Material mat = new Material();
    Mesh mesh = new Mesh(md, mat)..rotX(3.14 / 2);
    //mesh.rotY(3.14);
    Node n = new Node(mesh);
    //n.invert = true;
    n.lookAt(new VM.Vector3(100.0, 0.0, 0.0));
    //n.matrix.scale(0.02);
    prg.add(n);
    animate(0.0);
  });
}
