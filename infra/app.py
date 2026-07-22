#!/usr/bin/env python3
"""CDK App entry point para BabyHealth."""
import aws_cdk as cdk
from stacks.babyhealth_stack import BabyHealthStack

app = cdk.App()

BabyHealthStack(
    app,
    "BabyHealthStack",
    env=cdk.Environment(region="us-east-1"),
    description="BabyHealth - Infraestructura para análisis de salud infantil con IA",
)

app.synth()
