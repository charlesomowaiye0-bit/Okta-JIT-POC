from __future__ import annotations
import boto3


# ARN service-prefix → registry target_type
_SERVICE_TO_TYPE = {
    "s3":             "s3",
    "secretsmanager": "secretsmanager",
}


def discover_targets() -> dict[str, list[str]]:
    """Query Resource Groups Tagging API for resources tagged JIT=true.
    Returns {target_type: [identifier, ...]} grouped by service.
    Identifiers are bucket names (for s3) or full ARNs (for secretsmanager) — matching what
    `app.shared.targets.registry.build()` expects."""
    client = boto3.client("resourcegroupstaggingapi")
    paginator = client.get_paginator("get_resources")
    pages = paginator.paginate(TagFilters=[{"Key": "JIT", "Values": ["true"]}])

    out: dict[str, list[str]] = {t: [] for t in _SERVICE_TO_TYPE.values()}
    for page in pages:
        for r in page.get("ResourceTagMappingList", []):
            arn = r["ResourceARN"]
            service = arn.split(":")[2]
            target_type = _SERVICE_TO_TYPE.get(service)
            if target_type is None:
                continue
            identifier = arn.split(":::")[-1] if target_type == "s3" else arn
            out[target_type].append(identifier)
    return out
