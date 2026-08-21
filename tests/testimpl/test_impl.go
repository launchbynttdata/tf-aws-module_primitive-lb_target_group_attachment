// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package testimpl

import (
	"context"
	"os"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	elbv2 "github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2"
	elbv2types "github.com/aws/aws-sdk-go-v2/service/elasticloadbalancingv2/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	lcaftypes "github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	expectedTargetIP   = "10.0.1.100"
	expectedTargetPort = int32(80)
	additionalTargetIP = "10.0.1.200"
)

// expectedRegion returns the region the example is expected to deploy into.
// It mirrors the AWS provider's region-resolution order (AWS_DEFAULT_REGION,
// AWS_REGION, then the hard-coded value in examples/complete/provider.tf).
func expectedRegion() string {
	if r := os.Getenv("AWS_DEFAULT_REGION"); r != "" {
		return r
	}
	if r := os.Getenv("AWS_REGION"); r != "" {
		return r
	}
	return "us-east-2"
}

func newELBv2Client(t *testing.T) *elbv2.Client {
	t.Helper()
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(expectedRegion()))
	require.NoError(t, err, "must be able to load AWS SDK config")
	return elbv2.NewFromConfig(cfg)
}

func describeRegisteredTarget(t *testing.T, client *elbv2.Client, targetGroupArn, targetID string, expectedPort int32) elbv2types.TargetHealthDescription {
	t.Helper()
	out, err := client.DescribeTargetHealth(context.Background(), &elbv2.DescribeTargetHealthInput{
		TargetGroupArn: aws.String(targetGroupArn),
	})
	require.NoError(t, err, "DescribeTargetHealth must succeed")
	require.NotEmpty(t, out.TargetHealthDescriptions, "target group must have at least one registered target")

	for _, desc := range out.TargetHealthDescriptions {
		require.NotNil(t, desc.Target, "target descriptor must not be nil")
		require.NotNil(t, desc.Target.Id, "target id must not be nil")
		if *desc.Target.Id != targetID {
			continue
		}
		require.NotNil(t, desc.Target.Port, "registered target must expose a port")
		assert.Equal(t, expectedPort, *desc.Target.Port, "registered target port must match expected port")
		return desc
	}
	require.FailNowf(t, "registered target not found",
		"target_id %q was not found among the registered targets of %q", targetID, targetGroupArn)
	return elbv2types.TargetHealthDescription{}
}

// TestComposableComplete is the full lifecycle / functional test. It verifies
// the module's Terraform outputs, confirms the target is registered with the
// target group via the AWS API, and then exercises the resource by performing
// a write operation: registering an additional target out-of-band, asserting
// it appears in the target group, and deregistering it again.
func TestComposableComplete(t *testing.T, ctx lcaftypes.TestContext) {
	opts := ctx.TerratestTerraformOptions()
	targetGroupArn := terraform.OutputContext(t, context.Background(), opts, "target_group_arn")
	require.NotEmpty(t, targetGroupArn, "target_group_arn output must not be empty")
	require.NotEmpty(t, terraform.OutputContext(t, context.Background(), opts, "id"), "id output must not be empty")

	t.Run("ModuleOutputsMatchInputs", func(t *testing.T) {
		assert.Equal(t, expectedTargetIP, terraform.OutputContext(t, context.Background(), opts, "target_id"),
			"target_id output must match the IP set in test.tfvars")
		assert.Equal(t, "80", terraform.OutputContext(t, context.Background(), opts, "port"),
			"port output must match the port set in test.tfvars")
		assert.Equal(t, expectedRegion(), terraform.OutputContext(t, context.Background(), opts, "region"),
			"region output must equal the provider region (computed when var.attachment_region is null)")
	})

	client := newELBv2Client(t)

	t.Run("PrimaryTargetIsRegistered", func(t *testing.T) {
		describeRegisteredTarget(t, client, targetGroupArn, expectedTargetIP, expectedTargetPort)
	})

	t.Run("AdditionalTargetCanBeRegisteredAndDeregistered", func(t *testing.T) {
		_, err := client.RegisterTargets(context.Background(), &elbv2.RegisterTargetsInput{
			TargetGroupArn: aws.String(targetGroupArn),
			Targets: []elbv2types.TargetDescription{{
				Id:   aws.String(additionalTargetIP),
				Port: aws.Int32(expectedTargetPort),
			}},
		})
		require.NoError(t, err, "RegisterTargets must succeed")

		t.Cleanup(func() {
			_, err := client.DeregisterTargets(context.Background(), &elbv2.DeregisterTargetsInput{
				TargetGroupArn: aws.String(targetGroupArn),
				Targets: []elbv2types.TargetDescription{{
					Id:   aws.String(additionalTargetIP),
					Port: aws.Int32(expectedTargetPort),
				}},
			})
			assert.NoError(t, err, "DeregisterTargets must succeed during cleanup")
		})

		describeRegisteredTarget(t, client, targetGroupArn, additionalTargetIP, expectedTargetPort)
	})
}

// TestComposableCompleteReadonly performs only read-only verification: it
// asserts the module's Terraform outputs and confirms via the AWS API that
// the configured target is registered. It must not register, deregister, or
// otherwise mutate the target group state.
func TestComposableCompleteReadonly(t *testing.T, ctx lcaftypes.TestContext) {
	opts := ctx.TerratestTerraformOptions()
	targetGroupArn := terraform.OutputContext(t, context.Background(), opts, "target_group_arn")
	require.NotEmpty(t, targetGroupArn, "target_group_arn output must not be empty")
	require.NotEmpty(t, terraform.OutputContext(t, context.Background(), opts, "id"), "id output must not be empty")

	t.Run("ModuleOutputsMatchInputs", func(t *testing.T) {
		assert.Equal(t, expectedTargetIP, terraform.OutputContext(t, context.Background(), opts, "target_id"),
			"target_id output must match the IP set in test.tfvars")
		assert.Equal(t, "80", terraform.OutputContext(t, context.Background(), opts, "port"),
			"port output must match the port set in test.tfvars")
		assert.Equal(t, expectedRegion(), terraform.OutputContext(t, context.Background(), opts, "region"),
			"region output must equal the provider region (computed when var.attachment_region is null)")
	})

	t.Run("PrimaryTargetIsRegistered", func(t *testing.T) {
		client := newELBv2Client(t)
		describeRegisteredTarget(t, client, targetGroupArn, expectedTargetIP, expectedTargetPort)
	})
}
