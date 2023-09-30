# -----------------------------------------------------------------------------
# AWS EFS CSI Driver (managed add-on)
# -----------------------------------------------------------------------------
# Enables ReadWriteMany persistent volumes backed by Amazon EFS. Uses the EKS
# managed add-on rather than Helm to benefit from AWS-managed lifecycle and
# automatic version compatibility with the cluster.
#
# After applying, create StorageClass and PersistentVolumeClaim resources:
#
#   apiVersion: storage.k8s.io/v1
#   kind: StorageClass
#   metadata:
#     name: efs
#   provisioner: efs.csi.aws.com
#   parameters:
#     provisioningMode: efs-ap
#     fileSystemId: <var.efs_file_system_id>
#     directoryPerms: "700"
# -----------------------------------------------------------------------------

resource "aws_eks_addon" "efs_csi" {
  count = var.enable_efs_csi_driver ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "aws-efs-csi-driver"
  addon_version               = var.efs_csi_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(local.common_tags, {
    AddOn = "aws-efs-csi-driver"
  })
}
