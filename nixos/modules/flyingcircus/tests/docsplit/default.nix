import ../../../../tests/make-test.nix ({ pkgs, ... }:
{
  name = "docsplit";

  nodes = {
    docsplitVM =
      { pkgs, config, ... }:
      {
        imports = [
          ../setup.nix
          ../../static
        ];
        config = {
          virtualisation.memorySize = 1024;
        };
      };
  };

  testScript = with pkgs; ''
    $docsplitVM->succeed(<<'__SHELL__');
    set -ex
    mkdir $HOME/docx
    cd $HOME/docx
    cp ${./document.docx} document.docx
    export OFFICE_PATH=${pkgs.libreoffice}/bin
    ${docsplit}/bin/docsplit text document.docx
    grep "Cat content" document.txt
    ${docsplit}/bin/docsplit images document.docx
    ${file}/bin/file document_1.png | grep "PNG image data, 1275 x 1650"
    __SHELL__

    $docsplitVM->succeed(<<'__SHELL__');
    set -ex
    mkdir $HOME/pdf
    cd $HOME/pdf
    cp ${./document.pdf} document.pdf
    ${docsplit}/bin/docsplit text document.pdf
    grep "Cat content" document.txt
    ${docsplit}/bin/docsplit images document.pdf
    ${file}/bin/file document_1.png | grep "PNG image data, 1275 x 1650"
    __SHELL__
  '';
})
