require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class MultiBackendTest < ActiveSupport::TestCase

  def test_should_save_in_multiple_stores
    attachment_model MultiStoreAttachmentTwoDefaults
    assert_created do 
      attachment = upload_file :filename => '/files/rails.png'
      assert attachment.dbfile_file.current_data 
      assert File.exist?(attachment.fs_file.full_filename)
      assert Set.new(attachment.stores) == Set.new([:dbfile, :fs])
    end
  end
  
  def test_should_destroy_from_both_stores
    attachment_model MultiStoreAttachmentTwoDefaults
    attachment = upload_file :filename => '/files/rails.png'
    attachment.destroy
    assert !File.exist?(attachment.fs_file.full_filename)
    assert attachment.db_file.destroyed?
  end


  def test_should_save_to_targed_stores
    attachment_model MultiStoreAttachmentTwoDefaults
    att = nil 
    assert_created do
      use_temp_file '/files/rails.png' do |file|
        att = attachment_model.new :uploaded_data => fixture_file_upload(file, 'image/png')
        att.stores = :dbfile
        att.save
      end
    end
  
    assert att.db_file 
    assert !File.exist?(att.fs_file.full_filename) 
  end

  def test_should_update_to_targeted_stores
    attachment_model MultiStoreAttachmentTwoDefaults
    attachment = upload_file :filename => '/files/rails.png'
    assert !attachment.new_record?
    attachment.stores = :dbfile
    attachment.save
    
    assert !File.exist?(attachment.fs_file.full_filename) 

    attachment.stores = [:dbfile, :fs]
    attachment.save
    assert File.exist?(attachment.fs_file.full_filename) 
    assert attachment.db_file

    attachment.stores = [:fs]
    attachment.save
    assert File.exist?(attachment.fs_file.full_filename) 
    assert attachment.db_file.destroyed?
  end 

  def test_should_rename_to_multiple_stores
    attachment_model MultiStoreAttachmentTwoFilesystems
    attachment = upload_file :filename => '/files/rails.png'

    assert(File.exist?(attachment.fs1_file.full_filename))
    assert(File.exist?(attachment.fs2_file.full_filename))
    old_filenames = [attachment.fs1_file.full_filename, attachment.fs2_file.full_filename]

    attachment.filename = 'renamed.png'
    attachment.save
    assert(attachment.fs1_file.full_filename =~ /renamed\.png/)
    assert(File.exist?(attachment.fs1_file.full_filename))
    assert(File.exist?(attachment.fs2_file.full_filename))
    old_filenames.each { |old| assert !File.exist?(old) }
  end

  def test_should_respect_existing_over_defaults
    attachment_model MultiStoreAttachmentTwoFilesystems

    attachment = upload_file :filename => '/files/rails.png'
    attachment.stores = :fs1
    attachment.save

    assert(!File.exist?(attachment.fs2_file.full_filename))

    attachment.reload
    attachment.save

    assert(!File.exist?(attachment.fs2_file.full_filename))

  end

  def test_should_fail_without_default
    attachment_model MultiStoreAttachmentNoDefault
    assert_raise(RuntimeError) do 
      attachment = upload_file :filename => '/files/rails.png'
    end
  end

  def test_should_create_multiple_thumbnails
    attachment_model MultiStoreAttachmentWithThumbnails
    
    attachment = upload_file :filename => '/files/rails.png'

    assert File.exist?(attachment.thumbnails.first.fs1_file.full_filename)
    assert File.exist?(attachment.thumbnails.first.fs2_file.full_filename)
  end
  
  def test_should_destroy_multiple_thumbnails
    attachment_model MultiStoreAttachmentWithThumbnails
    
    attachment = upload_file :filename => '/files/rails.png'

    attachment.destroy
    assert !File.exist?(attachment.thumbnails.first.fs1_file.full_filename)
    assert !File.exist?(attachment.thumbnails.first.fs2_file.full_filename)
  end
  
  def test_should_destroy_targeted_thumbnails
    attachment_model MultiStoreAttachmentWithThumbnails
    
    attachment = upload_file :filename => '/files/rails.png'
    attachment.stores = :fs1
    attachment.save
    assert File.exist?(attachment.thumbnails.first.fs1_file.full_filename)
    assert !File.exist?(attachment.thumbnails.first.fs2_file.full_filename), "Second thumbnail was not destroyed"
  end
end
