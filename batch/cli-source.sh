#

function create-compute-stack {
	aws cloudformation create-stack \
		--stack-name $1 \
		--template-body "file://batch.yml"
}

function delete-compute-stack {
	aws cloudformation delete-stack \
		--stack-name $1
}