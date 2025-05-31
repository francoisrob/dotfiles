function deploy-all --description 'Auto-deploy dev, stage, prod using SAM'

    set profile francois-iot
    set envs dev stage prod

    for env in $envs
        echo ""
        echo "🔄 Deploying to $env..."

        echo "🔍 Validating ($env)..."
        sam validate --config-env $env --profile $profile
        or begin
            echo "❌ Validation failed for $env."
            return 1
        end

        echo "🛠️  Building ($env)..."
        sam build --config-env $env
        or begin
            echo "❌ Build failed for $env."
            return 1
        end

        echo "🚀 Deploying ($env)..."

        if test "$env" = dev
            sam deploy \
                --profile $profile \
                --no-confirm-changeset \
                --no-fail-on-empty-changeset \
                --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
        else
            sam deploy \
                --config-env $env \
                --profile $profile \
                --no-confirm-changeset \
                --no-fail-on-empty-changeset \
                --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
        end

        or begin
            echo "❌ Deployment failed for $env."
            return 1
        end

        echo "✅ Successfully deployed $env."
    end

    echo ""
    echo "🎉 All environments deployed successfully!"
end
