import 'package:chronosgl/chronosgl.dart';
import 'package:chronosgl/chronosutil.dart';
import 'dart:html' as HTML;
import "dart:async";

String textureFile = "sphere.png";
// https://cycling74.com/forums/topic/shader-help-recreating-gl_sphere_map/
// https://www.opengl.org/wiki/Mathematics_of_glTexGen

String _SphereV = """
  vec3 u = normalize(vec3(${uModelMatrix} * vec4(${aVertexPosition}, 1.0)));
  vec3 n = normalize(${uNormalMatrix} * ${aNormal} );
  vec3 r = reflect( u, n );
  r.z += 1.0;
  float m = 2.0 * length(r);
  ${vTextureCoordinates} = vec2(r.x/m + 0.5, r.y/m + 0.5);
""";

List<ShaderObject> sphereShader() {
  return [
    new ShaderObject("sphereV")
      ..AddAttributeVar(aVertexPosition)
      ..AddAttributeVar(aNormal)
      ..AddUniformVar(uPerspectiveViewMatrix)
      ..AddUniformVar(uModelMatrix)
      ..AddUniformVar(uNormalMatrix)
      ..AddVaryingVar(vTextureCoordinates)
      ..SetBodyWithMain([StdVertexBody, _SphereV]),
    new ShaderObject("sphereF")
      ..AddVaryingVar(vTextureCoordinates)
      ..AddUniformVar(uTexture)
      ..SetBodyWithMain(
          ["gl_FragColor = texture2D(${uTexture}, ${vTextureCoordinates});"])
  ];
}

void main() {
  StatsFps fps =
      new StatsFps(HTML.document.getElementById("stats"), "blue", "gray");
  HTML.CanvasElement canvas = HTML.document.querySelector('#webgl-canvas');
  ChronosGL chronosGL = new ChronosGL(canvas);
  OrbitCamera orbit = new OrbitCamera(5.0, 10.0);
  Perspective perspective = new Perspective(orbit);
  RenderPhase phase = new RenderPhase("main", chronosGL.gl);

  RenderProgram sprites = phase.createProgram(createPointSpritesShader());
  sprites.add(Utils.MakeParticles(chronosGL.gl, 2000));

  RenderProgram shaderSpheres = phase.createProgram(sphereShader());
  Material mat =
      new Material.Transparent("sphere", new BlendEquation.Mix());

  MeshData md = ShapeIcosahedron(chronosGL.gl, 3);
  Node m = new Node("sphere", md, mat)..setPos(0.0, 0.0, 0.0);

  shaderSpheres.add(m);

  void resolutionChange(HTML.Event ev) {
    int w = canvas.clientWidth;
    int h = canvas.clientHeight;
    canvas.width = w;
    canvas.height = h;
    print("size change $w $h");
    perspective.AdjustAspect(w, h);
    phase.viewPortW = w;
    phase.viewPortH = h;
  }

  resolutionChange(null);
  HTML.window.onResize.listen(resolutionChange);

  double _lastTimeMs = 0.0;
  void animate(timeMs) {
    timeMs = 0.0 + timeMs;
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs;
    orbit.azimuth += 0.001;
    orbit.animate(elapsed);
    fps.UpdateFrameCount(timeMs);
    phase.draw([perspective]);
    HTML.window.animationFrame.then(animate);
  }

  List<Future<dynamic>> futures = [
    LoadImage(textureFile),
  ];
  Future.wait(futures).then((List list) {
    Texture bubble = new WebTexture(chronosGL.gl, textureFile, list[0]);
    mat..SetUniform(uTexture, bubble);
    animate(0.0);
  });
}
