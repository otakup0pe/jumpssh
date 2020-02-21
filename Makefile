test:
	for script in *.sh ; do \
		echo "Shellchecking $$script" ; \
		docker run --rm -v "$(shell pwd):/mnt" "koalaman/shellcheck-alpine:stable" "shellcheck" "/mnt/$$script" ; \
	done

.PHONY = test
