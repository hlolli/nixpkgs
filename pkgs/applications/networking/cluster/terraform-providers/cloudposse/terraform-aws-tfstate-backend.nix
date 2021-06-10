{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "terraform-aws-tfstate-backend";
  version = "0.33.0";

  vendorSha256 = "sha256-2rTIfcOQV4yyrsjyFzBjnTFEba94Wwojsq2QWXlCIew=";

  src = fetchFromGitHub {
    owner = "cloudposse";
    repo = pname;
    rev = version;
    sha256 = "sha256-9vH0Tu+aqSPm01VvypevX+SfQbAo9HVRoRJhcYFPl1E=";
  };

  preBuild = "rm -rf test; cp ${./tfstate.go.mod} go.mod; chmod +rw go.mod";

  meta = with lib; {
    homepage = "https://github.com/cloudposse/terraform-aws-tfstate-backend";
    description = "Terraform module to provision an S3 bucket to store";
    longDescription = ''
      Terraform module that provision an S3 bucket to store the
      `terraform.tfstate` file and a DynamoDB table to lock the
      state file to prevent concurrent modifications
      and state corruption.
    '';
    license = licenses.asl20;
    maintainers = with maintainers; [ hlolli ];
  };
}
