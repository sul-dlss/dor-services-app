# frozen_string_literal: true

# NOTE:  this class makes use of data structures from moab-versioning gem,
#  but it does NOT access any preservation storage roots
class DigitalStacksService
  # Delete files from stacks that have change type 'deleted', 'copydeleted', or 'modified'
  # @param [Pathname] stacks_object_pathname the stacks location of the digital object
  # @param [Moab::FileGroupDifference] content_diff the content file version differences report
  def self.remove_from_stacks(stacks_object_pathname, content_diff)
    %i[deleted copydeleted modified].each do |change_type|
      subset = content_diff.subset(change_type) # {Moab::FileGroupDifferenceSubset}
      subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
        moab_signature = moab_file.signatures.first # {Moab::FileSignature}
        file_pathname = stacks_object_pathname.join(moab_file.basis_path)
        delete_file(file_pathname, moab_signature)
      end
    end
  end

  # Delete a file, but only if it exists and matches the expected signature
  # @param [Pathname] file_pathname The location of the file to be deleted
  # @param [Moab::FileSignature] moab_signature The fixity values of the file
  # @return [Boolean] true if file deleted, false otherwise
  def self.delete_file(file_pathname, moab_signature)
    if file_pathname.exist? && (file_pathname.size == moab_signature.size.to_i)
      file_signature = Moab::FileSignature.new.signature_from_file(file_pathname)
      if file_signature == moab_signature
        file_pathname.delete
        return true
      end
    end
    false
  end

  # Rename files from stacks that have change type 'renamed' using an intermediate temp filename.
  # The 2-step renaming allows chained or cyclic renames to occur without file collisions.
  # @param [Pathname] stacks_object_pathname the stacks location of the digital object
  # @param [Moab::FileGroupDifference] content_diff the content file version differences report
  def self.rename_in_stacks(stacks_object_pathname, content_diff)
    subset = content_diff.subset(:renamed) # {Moab::FileGroupDifferenceSubset

    # 1st Pass - rename files from original name to checksum-based name
    subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
      moab_signature = moab_file.signatures.first # {Moab::FileSignature}
      original_pathname = stacks_object_pathname.join(moab_file.basis_path)
      temp_pathname = stacks_object_pathname.join(moab_signature.checksums.values.last)
      rename_file(original_pathname, temp_pathname, moab_signature)
    end

    # 2nd Pass - rename files from checksum-based name to new name
    subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
      moab_signature = moab_file.signatures.first # {Moab::FileSignature}
      temp_pathname = stacks_object_pathname.join(moab_signature.checksums.values.last)
      new_pathname = stacks_object_pathname.join(moab_file.other_path)
      rename_file(temp_pathname, new_pathname, moab_signature)
    end
  end

  # Rename a file, but only if it exists and has the expected signature
  # @param [Pathname] old_pathname The original location/name of the file being renamed
  # @param [Pathname] new_pathname The new location/name of the file
  # @param [Moab::FileSignature] moab_signature The fixity values of the file
  # @return [Boolean] true if file renamed, false otherwise
  def self.rename_file(old_pathname, new_pathname, moab_signature)
    if old_pathname.exist? && (old_pathname.size == moab_signature.size.to_i)
      file_signature = Moab::FileSignature.new.signature_from_file(old_pathname)
      if file_signature == moab_signature
        new_pathname.parent.mkpath
        old_pathname.rename(new_pathname)
        return true
      end
    end
    false
  end

  # Add files to stacks that have change type 'added', 'copyadded' or 'modified'.
  # @param [Pathname] workspace_content_pathname The dor workspace location of the digital object's content fies
  # @param [Pathname] stacks_object_pathname the stacks location of the digital object's shelved files
  # @param [Moab::FileGroupDifference] content_diff the content file version differences report
  def self.shelve_to_stacks(workspace_content_pathname, stacks_object_pathname, content_diff)
    return false if workspace_content_pathname.nil?

    %i[added copyadded modified].each do |change_type|
      subset = content_diff.subset(change_type) # {Moab::FileGroupDifferenceSubset
      subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
        moab_signature = moab_file.signatures.last # {Moab::FileSignature}
        filename = change_type == :modified ? moab_file.basis_path : moab_file.other_path
        workspace_pathname = workspace_content_pathname.join(filename)
        stacks_pathname = stacks_object_pathname.join(filename)
        copy_file(workspace_pathname, stacks_pathname, moab_signature)
      end
    end
    true
  end

  # Copy a file to stacks, but only if it does not yet exist with the expected signature
  # @param [Pathname] workspace_pathname The location of the file in the DOR workspace
  # @param [Pathname] stacks_pathname The location of the file in the stacks
  # @param [Moab::FileSignature] moab_signature The fixity values of the file
  # @return [Boolean] true if file copied, false otherwise
  def self.copy_file(workspace_pathname, stacks_pathname, moab_signature)
    if stacks_pathname.exist?
      file_signature = Moab::FileSignature.new.signature_from_file(stacks_pathname)

      if file_signature == moab_signature
        Rails.logger.debug("[Shelve] Found existing file with the same signature at #{stacks_pathname}")
      else
        Rails.logger.debug("[Shelve] Found existing file with different signature at #{stacks_pathname}")
        stacks_pathname.delete
      end
    end
    unless stacks_pathname.exist?
      stacks_pathname.parent.mkpath
      Rails.logger.debug("[Shelve] Copying #{workspace_pathname} to #{stacks_pathname}")
      FileUtils.cp workspace_pathname.to_s, stacks_pathname.to_s
      # Change permissions
      FileUtils.chmod 'u=rw,go=r', stacks_pathname.to_s
      return true
    end
    false
  end
end
