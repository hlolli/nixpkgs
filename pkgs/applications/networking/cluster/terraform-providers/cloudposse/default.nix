{ callPackage }:

{
  terraform-aws-tfstate-backend = callPackage ./terraform-aws-tfstate-backend.nix {};
}
